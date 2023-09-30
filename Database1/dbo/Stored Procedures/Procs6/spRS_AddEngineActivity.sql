CREATE PROCEDURE dbo.spRS_AddEngineActivity
@Engine_Name 	 VARCHAR(50),
@Engine_Id  	  	 INT,
@Message  	  	 VARCHAR(255),
@ErrorLevel  	 INT = Null,
@Report_Id  	  	 INT = Null,
@Run_Id  	  	 INT = Null
 AS
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
Insert Into Report_Engine_Activity(Engine_Name, Engine_Id, Message, Time, ErrorLevel, Report_Id, Run_Id)
Values(@Engine_Name, @Engine_Id, @Message, @Now, @ErrorLevel, @Report_Id, @Run_Id)
