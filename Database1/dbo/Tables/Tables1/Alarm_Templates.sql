CREATE TABLE [dbo].[Alarm_Templates] (
    [AT_Id]                        INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Action_Required]              BIT                       CONSTRAINT [AlarmTmpl_DF_ActionReq] DEFAULT ((0)) NOT NULL,
    [Action_Tree_Id]               INT                       NULL,
    [Alarm_Type_Id]                INT                       CONSTRAINT [DF_Alarm_Templates_Alarm_Type_Id] DEFAULT ((1)) NOT NULL,
    [AP_Id]                        INT                       NOT NULL,
    [AT_Desc]                      [dbo].[Varchar_Desc]      NOT NULL,
    [Cause_Required]               BIT                       CONSTRAINT [AlarmTmpl_DF_CauseReq] DEFAULT ((0)) NOT NULL,
    [Cause_Tree_Id]                INT                       NULL,
    [Comment_Id]                   INT                       NULL,
    [Custom_Text]                  [dbo].[Varchar_Long_Desc] NULL,
    [Default_Action1]              INT                       NULL,
    [Default_Action2]              INT                       NULL,
    [Default_Action3]              INT                       NULL,
    [Default_Action4]              INT                       NULL,
    [Default_Cause1]               INT                       NULL,
    [Default_Cause2]               INT                       NULL,
    [Default_Cause3]               INT                       NULL,
    [Default_Cause4]               INT                       NULL,
    [DQ_Criteria]                  TINYINT                   NULL,
    [DQ_Tag]                       VARCHAR (255)             NULL,
    [DQ_Value]                     [dbo].[Varchar_Value]     NULL,
    [DQ_Var_Id]                    INT                       NULL,
    [ESignature_Level]             INT                       NULL,
    [Event_Reason_Tree_Data_Id]    INT                       NULL,
    [Lower_Entry]                  BIT                       CONSTRAINT [AlarmTmpl_DF_LE] DEFAULT ((0)) NOT NULL,
    [Lower_Reject]                 BIT                       CONSTRAINT [AlarmTmpl_DF_LR] DEFAULT ((0)) NOT NULL,
    [Lower_User]                   BIT                       CONSTRAINT [AlarmTmpl_DF_LU] DEFAULT ((0)) NOT NULL,
    [Lower_Warning]                BIT                       CONSTRAINT [AlarmTmpl_DF_LW] DEFAULT ((0)) NOT NULL,
    [SP_Name]                      VARCHAR (255)             NULL,
    [String_Specification_Setting] TINYINT                   NULL,
    [Target]                       BIT                       CONSTRAINT [AlarmTmpl_DF_TGT] DEFAULT ((0)) NOT NULL,
    [Upper_Entry]                  BIT                       CONSTRAINT [AlarmTmpl_DF_UE] DEFAULT ((0)) NOT NULL,
    [Upper_Reject]                 BIT                       CONSTRAINT [AlarmTmpl_DF_UR] DEFAULT ((0)) NOT NULL,
    [Upper_User]                   BIT                       CONSTRAINT [AlarmTmpl_DF_UU] DEFAULT ((0)) NOT NULL,
    [Upper_Warning]                BIT                       CONSTRAINT [AlarmTmpl_DF_UW] DEFAULT ((0)) NOT NULL,
    [Use_AT_Desc]                  BIT                       CONSTRAINT [AlarmTmpl_DF_UseATDesc] DEFAULT ((0)) NOT NULL,
    [Use_Trigger_Desc]             BIT                       CONSTRAINT [AlarmTmpl_DF_UseTriggerDesc] DEFAULT ((0)) NOT NULL,
    [Use_Var_Desc]                 BIT                       CONSTRAINT [AlarmTmpl_DF_UseVarDesc] DEFAULT ((0)) NOT NULL,
    [Use_Line_Desc]                BIT                       CONSTRAINT [AlarmTmpl_DF_UseLineDesc] DEFAULT ((0)) NOT NULL,
    [Use_Unit_Desc]                BIT                       CONSTRAINT [AlarmTmpl_DF_UseUnitDesc] DEFAULT ((0)) NOT NULL,
    [Email_Table_Id]               INT                       NULL,
    CONSTRAINT [AlarmTmpl_PK_ATId] PRIMARY KEY NONCLUSTERED ([AT_Id] ASC),
    CONSTRAINT [Alarm_Templates_FK_Alarm_Types] FOREIGN KEY ([Alarm_Type_Id]) REFERENCES [dbo].[Alarm_Types] ([Alarm_Type_Id]),
    CONSTRAINT [AlarmTemp_FK_EventReasonTreeData] FOREIGN KEY ([Event_Reason_Tree_Data_Id]) REFERENCES [dbo].[Event_Reason_Tree_Data] ([Event_Reason_Tree_Data_Id]),
    CONSTRAINT [AlarmTmpl_FK_ActionTreeId] FOREIGN KEY ([Action_Tree_Id]) REFERENCES [dbo].[Event_Reason_Tree] ([Tree_Name_Id]),
    CONSTRAINT [AlarmTmpl_FK_ApId] FOREIGN KEY ([AP_Id]) REFERENCES [dbo].[Alarm_Priorities] ([AP_Id]),
    CONSTRAINT [AlarmTmpl_FK_DefAction1] FOREIGN KEY ([Default_Action1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTmpl_FK_DefAction2] FOREIGN KEY ([Default_Action2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTmpl_FK_DefAction3] FOREIGN KEY ([Default_Action3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTmpl_FK_DefAction4] FOREIGN KEY ([Default_Action4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTmpl_FK_DefCause1] FOREIGN KEY ([Default_Cause1]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTmpl_FK_DefCause2] FOREIGN KEY ([Default_Cause2]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTmpl_FK_DefCause3] FOREIGN KEY ([Default_Cause3]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [AlarmTmpl_FK_DefCause4] FOREIGN KEY ([Default_Cause4]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Alarm_Templates_UC_Desc] UNIQUE NONCLUSTERED ([AT_Desc] ASC)
);


GO
CREATE NONCLUSTERED INDEX [AlarmTmpl_IDX_ATDesc]
    ON [dbo].[Alarm_Templates]([AT_Desc] ASC);


GO
Create  TRIGGER dbo.AlarmTemplates_Reload_InsUpdDel
 	 ON dbo.Alarm_Templates
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
