Setup Steps

These reports require AD User discover to be enabled, and a few additional hardware inventory classes.

1. Upload the report to you SSRS server.
2. Create a CM data source pointed at your Configuration Manager database.  (copy from the builtin to start if needed)
3. Add the following attributes to AD User Discovery (displayName, company, department, l, title, Manager, telephoneNumber, streetAddress)
4. Enable the Win32_ComputerSystemProduct inventory class.
5. Enable the FreeSpace property in the LogicaDisk class.
6. The local users section relies on Sherry Kissingers "All Members of All Local Groups" 
https://www.mnscug.org/blogs/sherry-kissinger/244-all-members-of-all-local-groups-inventory-for-configmgr-2012