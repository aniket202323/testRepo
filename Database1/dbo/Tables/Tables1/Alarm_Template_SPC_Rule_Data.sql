CREATE TABLE [dbo].[Alarm_Template_SPC_Rule_Data] (
    [ATSRD_Id]                   INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alarm_SPC_Rule_Id]          INT     NOT NULL,
    [AP_Id]                      INT     NULL,
    [AT_Id]                      INT     NOT NULL,
    [Firing_Priority]            TINYINT NOT NULL,
    [SPC_Group_Variable_Type_Id] INT     NULL,
    CONSTRAINT [PK_Alarm_Template_SPC_Rule_Data] PRIMARY KEY NONCLUSTERED ([ATSRD_Id] ASC),
    CONSTRAINT [Alarm_Template_SPC_Rule_Data_FK_Alarm_SPC_Rules] FOREIGN KEY ([Alarm_SPC_Rule_Id]) REFERENCES [dbo].[Alarm_SPC_Rules] ([Alarm_SPC_Rule_Id]),
    CONSTRAINT [Alarm_Template_SPC_Rule_Data_FK_Alarm_Templates] FOREIGN KEY ([AT_Id]) REFERENCES [dbo].[Alarm_Templates] ([AT_Id]),
    CONSTRAINT [Alarm_Template_SPC_Rule_Data_FK_APId] FOREIGN KEY ([AP_Id]) REFERENCES [dbo].[Alarm_Priorities] ([AP_Id]),
    CONSTRAINT [Alarm_Template_SPC_Rule_Data_FK_SPCGroupVariableTypeId] FOREIGN KEY ([SPC_Group_Variable_Type_Id]) REFERENCES [dbo].[SPC_Group_Variable_Types] ([SPC_Group_Variable_Type_Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AlarmTemplateSPCRuleData_IX_ATIdRuleIdVarTypeId]
    ON [dbo].[Alarm_Template_SPC_Rule_Data]([AT_Id] ASC, [Alarm_SPC_Rule_Id] ASC, [SPC_Group_Variable_Type_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Alarm_Template_SPC_Rule_Data_IX_ATIdRuleIdFirePri]
    ON [dbo].[Alarm_Template_SPC_Rule_Data]([AT_Id] ASC, [Alarm_SPC_Rule_Id] ASC, [Firing_Priority] ASC);


GO
Create  TRIGGER dbo.AlarmTemplateSPCRuleData_Reload_InsUpdDel
 	 ON dbo.Alarm_Template_SPC_Rule_Data
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
