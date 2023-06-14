# Contributing

## Code
This resource uses Wally, which is installed through Aftman, to publish the code onto https://wally.run/. You may find Aftman here:
- https://github.com/LPGhatguy/aftman
After installation, Wally can be installed by running `aftman install` in the root directory of this project.

Additionally, Rojo may be used to sync the code to Roblox Studio. You may find Rojo here:
- https://rojo.space/

## Bug Reports & Feature Requests
Please use the [issue tracker](https://github.com/PysephWasntAvailable/RemotePacketSizeCounter/issues) to report any bugs or file feature requests.


## Developing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## Adding a new data type
To implement a new data type, the byte size must be measured as such:
1. Send data through remotes and log the outcome with Roblox's Network panel data
2. Perform the measurement three times, and then average the result
3. Do this measurement on three data amounts (10, 100, 1000), then perform linear regression to figure out the scale coefficient.

**Additional things to note:**
- Make sure the testing baseplate is utterly empty (disabling spawning, lighting, no map, etc.) to ensure that the data is not affected by other factors.
- Use the Performance Stats window & use the expanded 'Recv' tab to measure the data size.
https://cdn.discordapp.com/attachments/785870115463626765/1104087960472793108/image.png
- Even empty baseplates have a non-zero data size, which is around ~0.18KB/s. Subtract this constant from the measured data size.
- Space out the measurements by 3-5 seconds to ensure that the data is not affected by other factors, and take into account for the whole spike rather than just the peak.
The calculation for one spike can look as such:
(0.2 - 0.18) + (20 - 0.18) + (12 - 0.18) + (0.2 - 0.18) = 31.68KB/s


## License
[MIT](https://choosealicense.com/licenses/mit/)

## Contact
- Discord: Pyseph
- Roblox Developer Forum: https://devforum.roblox.com/u/pysephdev/summary
