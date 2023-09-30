/*
This procedure gets executed before any command is executed with
the .NET ISI.
Since connections in .NET are pooled, this cannot only be called once
for each connection.  It needs to be called for each command so that
all of the proper commands can be executed.
*/
Create Procedure [dbo].[spNISI_PreCommandExecute]
 	 --The user Id that the command is being executed for.  If this is supplied,
 	 --it will be used to update the "User_Connections" table.  It will also set
 	 --the primary/secondary language setting
 	 @UserId Int = Null,
 	 --The command text of the command that is about to be executed
 	 @CommandText Varchar(1000) = Null,
 	 --If the command text is supplied, this will contain the timeout from
 	 --"client_sp_prototypes" if possible.
 	 @CommandTimeoutSeconds Int Output,
 	 --This value will tell the caller if they need to set up the connection
 	 --to use the primary or secondary language. (Set NOCOUNT property).  This
 	 --will only be valid if the @UserId parameter has been set.
 	 @UsePrimaryLanguage Bit Output
As
Declare @SiteParamValue Varchar(5000)
If @UserId Is Not Null And @UserId > 0
 	 Begin
 	  	 Declare @MultiLingualEnabled Bit
 	  	 Declare @UserLanguage Int
 	  	 Print 'PlantApps:ISI:A user ID was specified, so the connection will be registered'
 	  	 Exec spNISI_RegisterConnection @UserId
 	  	 Print 'PlantApps:ISI:Determining if the user is set up for the primary or secondary language'
 	  	 Select @SiteParamValue = [Value]
 	  	 From Site_Parameters
 	  	 Where Parm_Id = 72
 	  	 If @SiteParamValue = '1' Or @SiteParamValue = 'true' 	 
 	  	  	 Begin
 	  	  	  	 Print 'PlantApps:ISI:Multi-lingual is enabled because of site parameter 72'
 	  	  	  	 
 	  	  	  	 --Look up the global secondary language
 	  	  	  	 Select @SiteParamValue = [Value]
 	  	  	  	 From Site_Parameters
 	  	  	  	 Where Parm_Id = 8
 	  	  	  	 --Look up the users language
 	  	  	  	 Select @UserLanguage = [Value]
 	  	  	  	 From User_Parameters
 	  	  	  	 Where Parm_Id = 8
 	  	  	  	 If @SiteParamValue Is Null Or @UserLanguage Is Null Or @SiteParamValue <> @UserLanguage
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Print 'PlantApps:ISI:Using the primary language for this user (NOCOUNT = Off)'
 	  	  	  	  	  	 Set @UsePrimaryLanguage = 1
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Print 'PlantApps:ISI:Using the secondary language for this user (NOCOUNT = On)'
 	  	  	  	  	  	 Set @UsePrimaryLanguage = 0
 	  	  	  	  	 End
 	  	  	 End
 	 End
If @CommandText Is Not Null And Len(@CommandText) > 0
 	 Begin
 	  	 Print 'PlantApps:ISI:Command text was specified, so the command timeout will be retrieved'
 	  	 Exec @CommandTimeoutSeconds = spNISI_GetCommandTimeout @CommandText
 	 End
Else
 	 Begin
 	  	 Set @CommandTimeoutSeconds = -1
 	 End
