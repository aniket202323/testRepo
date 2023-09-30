CREATE TABLE [dbo].[Local_PG_CL_Alarms_History] (
    [CLAlarm_History_Id]     INT                   IDENTITY (1, 1) NOT NULL,
    [CLAlarm_Id]             INT                   NOT NULL,
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
    [DBTT_Id]                TINYINT               NULL,
    PRIMARY KEY CLUSTERED ([CLAlarm_History_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Local_PG_CL_Alarms_History_IX_CLAlarm_Id]
    ON [dbo].[Local_PG_CL_Alarms_History]([CLAlarm_Id] ASC);

