This is a web service + frontend, that caches echonest api calls, after listening in on sonos media playlist updates.

This requires [node.js][1], [mongodb][2], and [foreman][3].

You can install node and mongodb through [homebrew][4], with `brew install node mongodb`

Foreman must be installed using rubygems, a lá `gem install foreman`

Then you can install the node libraries being used with `npm install`

And finally start up node application and mongodb server together with `foreman start`

There are two distribution scripts that help make sure the server has all the correct dependencies. One is for the raspberry pi, the other is for osx. Both are in the `dist` folder.

To start the server manually, double-click `engage.command`.

If you want to autostart, in OSX, do:

    sudo foreman export launchd /Library/LaunchDaemons/ --app sononest --user `whoami`
    sudo launchctl load /Library/LaunchDaemons/sononest*

[1]: http://nodejs.org
[2]: http://mongodb.org
[3]: https://github.com/ddollar/foreman
[4]: http://brew.sh/


Written by @jedahan and @danthemellowman for SONOS: Play a Visual Experience
