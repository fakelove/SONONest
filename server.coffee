util = require 'util'

restify = require 'restify'
swagger = require 'swagger-doc'
toobusy = require 'toobusy'
async = require 'async'

echojs = require 'echojs'
echo = echojs key: "ECHONEST_KEY"

SonosDiscovery = require 'sonos-discovery'
discovery = new SonosDiscovery()

Sonos = require 'Sonos'
search = Sonos.search()

osc = require 'node-osc'
client = new osc.Client 'YOUR.NETWORK.MULTICAST.ADDR', 7777
client._sock.on 'listening', ->
    client._sock.setBroadcast(true)
    client._sock.setMulticastTTL(255)

devices = []

search.on 'DeviceAvailable', (device) ->
  devices.push new Sonos.Sonos device.host, device.port

# MongoDB setup
Mongolian = require 'mongolian'
mongolian = new Mongolian
ObjectId = Mongolian.ObjectId
ObjectId.prototype.toJSON = ObjectId.prototype.toString
db = mongolian.db 'sononest'
tracks = db.collection 'tracks'

server = restify.createServer()
server.pre restify.pre.userAgentConnection()
server.use (req, res, next) -> toobusy() and res.send(503, "I'm busy right now, sorry.") or next()
server.use restify.queryParser()
server.use restify.acceptParser server.acceptable # respond correctly to accept headers
server.use restify.bodyParser()
server.use restify.fullResponse() # set CORS, eTag, other common headers

getTrack = (req, res, next) ->
  artist = req.params.artist
  title = req.params.title

  tracks.find({hash: artist+title}).toArray (err, body) ->
    console.error err if err

    if body.length
      res.send body
    else
      trackClient = restify.createJsonClient url: server.url
      echo('song/search').get {artist, title, results:"1"}, (err, json) ->
        echo('song/profile').get {id: json.response.songs?[0]?.id, bucket: "audio_summary"}, (err, trackinfo) ->
          tracks.insert {hash: artist+title, info: trackinfo.response }, (err, doc) ->
            res.send trackinfo.response?.songs?[0]

getCurrent = (req, res, next) ->
  discovery.getPlayer(decodeURIComponent(req.params.room)).state

getPlaylist = (req, res, next) ->
  playlists = []

  addPlaylist = (device, callback) ->
    device.getQueue (err, queue) ->
      if queue?.length
        q = {}
        q["#{device.host}:#{device.port}"] = queue
        playlists.push q
      callback null

  async.each devices, addPlaylist, (err) ->
    res.send playlists

handleTransportStateChange = (data) ->
	infoClient = restify.createJsonClient url: server.url
	infoClient.get "/track?artist=#{encodeURI(data.state.currentTrack.artist)}&title=#{encodeURI(data.state.currentTrack.title)}", (err, req, res, obj) ->
    	data.state.currentTrack.echonest = obj
    	infoClient.get "/track?artist=#{encodeURI(data.state.nextTrack.artist)}&title=#{encodeURI(data.state.nextTrack.title)}", (err, req, res, obj) ->
		console.log("osc-send-handleTransportStateChange");
		client.send "/newTrack/#{encodeURI(data.uuid)}", JSON.stringify data
				
handleTopologyChange = (data) ->
	for zone in discovery.zones
		for member in zone.members
			client.send "/topology-change/#{encodeURI(member.roomName)}", encodeURI(zone.coordinator.roomName)
			console.log("osc-send-handleTopologyChange");
	
	
###
  API
###
swagger.configure server

server.get "/track", getTrack

server.get "/current", getCurrent

server.get "/playlist", getPlaylist

server.get "/zones", (req, res, next) ->
  delete zone.coordinator.coordinator for zone in discovery.zones
  res.send discovery.zones

###
  Documentation
###
docs = swagger.createResource '/docs'

docs.get "/playlist", "List playlist for each group",
  nickname: "getPlaylist"

docs.get "/zones", "List zones",
  nickname: "getZones"

docs.get "/track", "Get track info from echonest cache",
  nickname: "getTrack"
  parameters: [
    { name: 'artist', description: 'artist name', required: true, dataType: 'string', paramType: 'query' }
    { name: 'title', description: 'track title', required: true, dataType: 'string', paramType: 'query' }
  ]

docs.get "/current", "Get current track for a particular room",
  nickname: "getCurrent"
  parameters: [
    { name: 'room', description: 'room name', required: true, dataType: 'string', paramType: 'query' }
  ]

server.get /\/*/, restify.serveStatic directory: './static', default: 'index.html'

server.listen process.env.PORT or 8081, ->
	discovery.on 'topology-change', handleTopologyChange
	discovery.on 'transport-state', handleTransportStateChange
	console.log "[%s] #{server.name} listening at #{server.url}", process.pid
