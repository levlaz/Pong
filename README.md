# Pong

Uptime monitoring as a self-deployed service.

Do you have servers that you need to ensure are up at all times? Are you also annoyed that dedicated uptime services cost *more* than the servers you're running on? Then just deploy your own monitoring server. That's where Pong comes in.

# Requirements for running locally

- a Redis server running on the port 6380 before booting the server (just `redis-server ./Redis/redis.conf` from the root folder to start the server with the desired config)
- environment variables for the target email address where to send alert emails when something goes down (`$PONG_EMAIL_TARGET`), [SendGrid](sendgrid.com) credentials in `$PONG_EMAIL_USERNAME` and `$PONG_EMAIL_PASSWORD`

:gift_heart: Contributing
------------
Please create an issue with a description of your problem or open a pull request with a fix.

:v: License
-------
MIT

:alien: Author
------
Honza Dvorsky - https://honzadvorsky.com, [@czechboy0](https://twitter.com/czechboy0)

