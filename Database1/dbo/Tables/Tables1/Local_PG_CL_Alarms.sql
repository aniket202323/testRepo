CREATE TABLE [dbo].[Local_PG_CL_Alarms] (
    [CLAlarm_Id]             INT                   IDENTITY (1, 1) NOT NULL,
    [Var_Id]                 INT                   NOT NULL,
    [Alarm_Id]               INT                   NOT NULL,
    [Test_Id]                BIGINT                NOT NULL,
    [Event_Subtype_Id]       INT                   NOT NULL,
    [PU_Id]                  INT                   NOT NULL,
    [Status_Tag]             INT                   NOT NULL,
    [Last_ModifiedTimeStamp] DATETIME              NULL,
    [L_Entry]                [dbo].[Varchar_Value] NULL,
    [L_Reject]               [dbo].[Varchar_Value] NULL,
    [L_User]                 [dbo].[Varchar_Value] NULL,
    [L_Warning]              [dbo].[Varchar_Value] NULL,
    [Prod_Id]                INT                   NOT NULL,
    [Target]                 [dbo].[Varchar_Value] NULL,
    [U_Entry]                [dbo].[Varchar_Value] NULL,
    [U_Reject]               [dbo].[Varchar_Value] NULL,
    [U_User]                 [dbo].[Varchar_Value] NULL,
    [U_Warning]              [dbo].[Varchar_Value] NULL,
    CONSTRAINT [PK_Local_PG_CL_Alarms] PRIMARY KEY NONCLUSTERED ([CLAlarm_Id] ASC)
);


GO

CREATE TRIGGER [dbo].[Local_PG_CL_Alarms_History_Del]
 ON  [dbo].[Local_PG_CL_Alarms]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 DECLARE	@Populate_History TinyInt,
			@DBTT_Id INT = 4; /*DBTT_Id with value 4 indicates insert operation*/

 SELECT @Populate_History = Value From Site_Parameters WHERE Parm_Id = 403
 IF (@Populate_History = 1 or @Populate_History = 3) 
   BEGIN
 	  	    INSERT INTO Local_PG_CL_Alarms_History
 	  		(CLAlarm_Id,Var_Id,Alarm_Id,Test_Id,Event_Subtype_Id,PU_Id,Status_Tag,Last_ModifiedTimeStamp,L_Entry,L_Reject,L_User,L_Warning,Prod_Id,Target,U_Entry,U_Reject,U_User,U_Warning,DBTT_Id)
 	  		SELECT  a.CLAlarm_Id,a.Var_Id,a.Alarm_Id,a.Test_Id,a.Event_Subtype_Id,a.PU_Id,a.Status_Tag,dbo.fnServer_CmnGetDate(getUTCdate()),a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Prod_Id,a.Target,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,@DBTT_Id
 	  		FROM Deleted a
   END

GO

CREATE TRIGGER [dbo].[Local_PG_CL_Alarms_History_Upd]
 ON  [dbo].[Local_PG_CL_Alarms]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 DECLARE	@Populate_History TinyInt,
			@DBTT_Id INT = 3; /*DBTT_Id with value 3 indicates insert operation*/

 SELECT @Populate_History = Value FROM Site_Parameters WHERE Parm_Id = 403
 IF (@Populate_History = 1 or @Populate_History = 3) 
   BEGIN
 	  	    INSERT INTO Local_PG_CL_Alarms_History
 	  	   (CLAlarm_Id,Var_Id,Alarm_Id,Test_Id,Event_Subtype_Id,PU_Id,Status_Tag,Last_ModifiedTimeStamp,L_Entry,L_Reject,L_User,L_Warning,Prod_Id,Target,U_Entry,U_Reject,U_User,U_Warning,DBTT_Id)
 	  	   SELECT  a.CLAlarm_Id,a.Var_Id,a.Alarm_Id,a.Test_Id,a.Event_Subtype_Id,a.PU_Id,a.Status_Tag,dbo.fnServer_CmnGetDate(getUTCdate()),a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Prod_Id,a.Target,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,@DBTT_Id
 	  	   FROM Inserted a
   END

GO

CREATE TRIGGER [dbo].[Local_PG_CL_Alarms_History_Ins]
 ON  [dbo].[Local_PG_CL_Alarms]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 DECLARE	@Populate_History TinyInt,
			@DBTT_Id INT = 2; /*DBTT_Id with value 2 indicates insert operation*/

 SELECT @Populate_History = Value FROM Site_Parameters WHERE Parm_Id = 403
 IF (@Populate_History = 1 or @Populate_History = 3) 
   BEGIN
 	  	    INSERT INTO Local_PG_CL_Alarms_History
 	  	   (CLAlarm_Id,Var_Id,Alarm_Id,Test_Id,Event_Subtype_Id,PU_Id,Status_Tag,Last_ModifiedTimeStamp,L_Entry,L_Reject,L_User,L_Warning,Prod_Id,Target,U_Entry,U_Reject,U_User,U_Warning,DBTT_Id)
 	  	   SELECT  a.CLAlarm_Id,a.Var_Id,a.Alarm_Id,a.Test_Id,a.Event_Subtype_Id,a.PU_Id,a.Status_Tag,dbo.fnServer_CmnGetDate(getUTCdate()),a.L_Entry,a.L_Reject,a.L_User,a.L_Warning,a.Prod_Id,a.Target,a.U_Entry,a.U_Reject,a.U_User,a.U_Warning,@DBTT_Id
 	  	   FROM Inserted a
   END
