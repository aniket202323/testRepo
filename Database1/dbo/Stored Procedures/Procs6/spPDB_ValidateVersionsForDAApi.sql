/**
<summary>
Validates that a client is compatible with the PDB.
</summary>
<returns>
(result set) The result set is described in the remarks section.
</returns>
<remarks>
The following tests are performed:
<list type="bullet">
<item>The PDB.NET API being used has a minimum PDB version it can
      talk to. Verify that the PDB is that version or later.</item>
<item>The PDB has a minimum version of the PDB.NET API that can
      talk to it. Verify that the PDB.NET API version is that version
      or later.</item>
<item>The client is associate with a module. Verify that the client's
      module is installed.</item>
<item>Verify that the client's module version is not greater than the
      the installed module. (The module in the PDB must be at the
      highest version of all clients connecting.)</item>
<item>The PDB has a minimum version of a particular module that
      can talk to it. Verify that the client's module version is
      that version or later.</item>
<item>Make sure that the module in enabled in the PDB.</item>
</list>
<para>
Returns a single row with several columns.
The first column is always the error code (0 means success).
The error codes returned here must match what is in
AdoClient.PdbVersionException.
The other named columns are to support creating meaningful error
messages.
</para>
</remarks>
*/
CREATE PROCEDURE dbo.spPDB_ValidateVersionsForDAApi
 	 @ModuleId INT, /** The calling client's module ID or -1 to skip module checks. */
 	 @ModuleVersion nvarchar(25), /** The calling client's module
 	                             version string (in database format). */
 	 @ApiVersion nvarchar(25),
 	    /** The calling client's PDB.NET API version string. */
 	 @ApiMinPdbVersion nvarchar(25)
 	     /** The min PDB version the calling
 	     client's API can use.
 	     */
AS
 	 DECLARE @ErrorCode INT
 	 DECLARE @PdbVersion nvarchar(25)
 	 DECLARE @MinApiVersion nvarchar(25)
 	 DECLARE @InstalledModuleVersion nvarchar(25)
 	 DECLARE @MinClientVersion nvarchar(25)
 	 DECLARE @ModuleIsEnabled TINYINT
    SELECT @ModuleVersion = LTRIM(RTRIM(@ModuleVersion))
    SELECT @ApiVersion = LTRIM(RTRIM(@ApiVersion))
    SELECT @ApiMinPdbVersion = LTRIM(RTRIM(@ApiMinPdbVersion))
 	 SELECT @ErrorCode = 0
 	 -- Check against the PDB version
 	 SELECT @PdbVersion = App_Version
 	  	 FROM AppVersions WHERE App_Id = 34
 	 IF @PdbVersion < @ApiMinPdbVersion
 	 BEGIN
 	  	 SELECT @ErrorCode = 1
 	  	 GOTO exit_label
 	 END
 	 -- Check against the API's version info
 	 SELECT @MinApiVersion = Min_Client_Version
 	  	 FROM Modules WHERE Module_Id = 19
 	 IF @ApiVersion < @MinApiVersion
 	 BEGIN
 	  	 -- client is using an old api (v{?}); upgrade to at least api version v{?}
 	  	 SELECT @ErrorCode = 2
 	  	 GOTO exit_label
 	 END
 	 IF @ModuleId >= 0
 	 BEGIN
 	  	 -- Check against the module's version info
 	  	 SELECT @InstalledModuleVersion = Installed_Version,
 	  	  	  	 @MinClientVersion = Min_Client_Version,
 	  	  	  	 @ModuleIsEnabled = Is_Enabled
 	  	  	 FROM Modules WHERE Module_Id = @ModuleId
 	  	 IF @InstalledModuleVersion IS NULL OR LEN(@InstalledModuleVersion) = 0
 	  	 BEGIN
 	  	  	 -- module not installed
 	  	  	 SELECT @ErrorCode = 3
 	  	  	 GOTO exit_label
 	  	 END
 	  	 IF @ModuleVersion > @InstalledModuleVersion
 	  	 BEGIN
 	  	  	 -- client module (v {0}) is too new; installed module is only at {1}
 	  	  	 SELECT @ErrorCode = 4
 	  	  	 GOTO exit_label
 	  	 END
 	  	 IF @ModuleVersion < @MinClientVersion
 	  	 BEGIN
 	  	  	 -- client module (v {0}) is too old; upgrade to at least {1}
 	  	  	 SELECT @ErrorCode = 5
 	  	  	 GOTO exit_label
 	  	 END
 	  	 IF @ModuleIsEnabled = 0 OR @ModuleIsEnabled IS NULL
 	  	 BEGIN
 	  	  	 -- module is installed but not enabled
 	  	  	 SELECT @ErrorCode = 6
 	  	  	 GOTO exit_label
 	  	 END
 	 END
exit_label:
 	 SELECT @ErrorCode AS 'Error_Code',
 	  	 @PdbVersion AS 'Pdb_Version',
 	  	 @MinApiVersion AS 'Min_Api_Version',
 	  	 @InstalledModuleVersion AS 'Installed_Module_Version',
 	  	 @MinClientVersion AS 'Min_Client_Version'
