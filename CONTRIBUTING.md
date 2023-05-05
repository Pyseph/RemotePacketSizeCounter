## Contributing
### Bug Reports & Feature Requests
Please use the [issue tracker](https://github.com/PysephWasntAvailable/RemotePacketSizeCounter/issues) to report any bugs or file feature requests.

### Developing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

### Adding a new data type
To implement a new data type, the byte size must be measured as such:
1. Send data through remotes and log the outcome with Roblox's Network panel data
2. Perform the measurement three times, and then average the result
3. Do this measurement on three data amounts (10, 100, 1000), then perform linear regression to figure out the scale coefficient.

- Make sure the testing baseplate is utterly empty (disabling spawning, lighting, no map, etc.) to ensure that the data is not affected by other factors.
- Use the 

### License
[MIT](https://choosealicense.com/licenses/mit/)

## Contact
Discord: Pyseph#0001
Roblox Developer Forum: https://devforum.roblox.com/u/pysephdev/summary