CREATE TABLE [dbo].[Alarm_Template_Var_Data] (
    [ATD_Id]                    INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AT_Id]                     INT                       NOT NULL,
    [ATSRD_Id]                  INT                       NULL,
    [ATVRD_Id]                  INT                       NULL,
    [Comment_Id]                INT                       NULL,
    [EG_Id]                     INT                       NULL,
    [Event_Reason_Tree_Data_Id] INT                       NULL,
    [Override_Action_Tree_Id]   INT                       NULL,
    [Override_Cause_Tree_Id]    INT                       NULL,
    [Override_Custom_Text]      [dbo].[Varchar_Long_Desc] NULL,
    [Override_Default_Action1]  INT                       NULL,
    [Override_Default_Action2]  INT                       NULL,
    [Override_Default_Action3]  INT                       NULL,
    [Override_Default_Action4]  INT                       NULL,
    [Override_Default_Cause1]   INT                       NULL,
    [Override_Default_Cause2]   INT                       NULL,
    [Override_Default_Cause3]   INT                       NULL,
    [Override_Default_Cause4]   INT                       NULL,
    [Override_DQ_Criteria]      TINYINT                   NULL,
    [Override_DQ_Tag]           VARCHAR (255)             NULL,
    [Override_DQ_Value]         [dbo].[Varchar_Value]     NULL,
    [Override_DQ_Var_Id]        INT                       NULL,
    [Var_Id]                    INT                       NOT NULL,
    [Sampling_Size]             INT                       NULL,
    CONSTRAINT [AlarmTemplateVarData_PK_ATDId] PRIMARY KEY NONCLUSTERED ([ATD_Id] ASC),
    CONSTRAINT [Alarm_Template_Var_Data_FK_ATSRDId] FOREIGN KEY ([ATSRD_Id]) REFERENCES [dbo].[Alarm_Template_SPC_Rule_Data] ([ATSRD_Id]),
    CONSTRAINT [Alarm_Template_Var_Data_FK_ATVRDId] FOREIGN KEY ([ATVRD_Id]) REFERENCES [dbo].[Alarm_Template_Variable_Rule_Data] ([ATVRD_Id]),
    CONSTRAINT [Alarm_Template_Var_Data_FK_EGId] FOREIGN KEY ([EG_Id]) REFERENCES [dbo].[Email_Groups] ([EG_Id]),
    CONSTRAINT [AlarmTempVD_FK_EventReasonTreeData] FOREIGN KEY ([Event_Reason_Tree_Data_Id]) REFERENCES [dbo].[Event_Reason_Tree_Data] ([Event_Reason_Tree_Data_Id]),
    CONSTRAINT [AlarmTempVD_FK_OATreeId] FOREIGN KEY ([Override_Action_Tree_Id]) REFERENCES [dbo].[Event_Reason_Tree] ([Tree_Name_Id]),
    CONSTRAINT [AlarmTempVD_FK_OCTreeId] FOREIGN KEY ([Override_Cause_Tree_Id]) REFERENCES [dbo].[Event_Reason_Tree] ([Tree_Name_Id]),
    CONSTRAINT [AlarmTempVD_FK_ODefAction1] FOREIGN KEY ([Override_Default_Action1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTempVD_FK_ODefAction2] FOREIGN KEY ([Override_Default_Action2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTempVD_FK_ODefAction3] FOREIGN KEY ([Override_Default_Action3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTempVD_FK_ODefAction4] FOREIGN KEY ([Override_Default_Action4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTempVD_FK_ODefCause1] FOREIGN KEY ([Override_Default_Cause1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTempVD_FK_ODefCause2] FOREIGN KEY ([Override_Default_Cause2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTempVD_FK_ODefCause3] FOREIGN KEY ([Override_Default_Cause3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTempVD_FK_ODefCause4] FOREIGN KEY ([Override_Default_Cause4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTVD_FK_ATId] FOREIGN KEY ([AT_Id]) REFERENCES [dbo].[Alarm_Templates] ([AT_Id]),
    CONSTRAINT [AlarmTVD_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);


GO
CREATE NONCLUSTERED INDEX [AlarmTVD_IDX_ATIdVarId]
    ON [dbo].[Alarm_Template_Var_Data]([AT_Id] ASC, [Var_Id] ASC);


GO
Create  TRIGGER dbo.AlarmTemplateVarData_Reload_InsUpdDel
 	 ON dbo.Alarm_Template_Var_Data
 	 FOR INSERT, UPDATE, DELETE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 Declare @ShouldReload Int
 	 Select @ShouldReload = sp.Value 
 	  	 From Parameters p
 	  	 Join Site_Parameters sp on p.Parm_Id = sp.Parm_Id
 	  	 Where Parm_Name = 'Perform automatic service reloads'
 	 If @ShouldReload is null or @ShouldReload = 0 
 	  	 Return
/*
2  -Database Mgr
4  -Event Mgr
5  -Reader
6  -Writer
7  -Summary Mgr
8  -Stubber
9  -Message Bus
14 -Gateway
16 -Email Engine
17 -Alarm Manager
18 -FTP Engine
19 -Calculation Manager
20 -Print Server
22 -Schedule Mgr
*/
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (17)
