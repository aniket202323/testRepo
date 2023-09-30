CREATE TABLE [dbo].[Event_Types] (
    [ET_Id]                      TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Add_As_Default]             TINYINT              CONSTRAINT [EventTypes_DF_AddAsDefault] DEFAULT ((0)) NOT NULL,
    [Allow_Multiple_Active]      BIT                  CONSTRAINT [Event_Types_DF_Allow_Multiple_Active] DEFAULT ((0)) NOT NULL,
    [AllowDataView]              TINYINT              NULL,
    [Comment_Text]               VARCHAR (2000)       NULL,
    [ET_Desc]                    [dbo].[Varchar_Desc] NOT NULL,
    [Event_Models]               INT                  NULL,
    [IncludeOnSoe]               TINYINT              CONSTRAINT [EventTypes_DF_IncludeOnSOE] DEFAULT ((0)) NOT NULL,
    [IsTimeBased]                TINYINT              NULL,
    [Module_Id]                  TINYINT              NULL,
    [parent_et_id]               TINYINT              NULL,
    [Single_Event_Configuration] BIT                  CONSTRAINT [Event_Types_DF_Single_Event_Configuration] DEFAULT ((0)) NOT NULL,
    [Subtypes_Apply]             TINYINT              CONSTRAINT [EventTypes_DF_SubtypesApply] DEFAULT ((0)) NOT NULL,
    [User_Configured]            TINYINT              CONSTRAINT [EventTypes_DF_UserConfigured] DEFAULT ((0)) NOT NULL,
    [ValidateTestData]           BIT                  CONSTRAINT [EventTypes_DF_ValidateTestData] DEFAULT ((0)) NOT NULL,
    [Variables_Assoc]            INT                  NULL,
    CONSTRAINT [Event_Types_PK_ETId] PRIMARY KEY CLUSTERED ([ET_Id] ASC),
    CONSTRAINT [Event_Types_FK_ModuleId] FOREIGN KEY ([Module_Id]) REFERENCES [dbo].[Modules] ([Module_Id])
);


GO
CREATE TRIGGER [dbo].[fnBF_ApiFindAvailableUnitsAndEventTypes_Event_Types_Sync]
  	  ON [dbo].[Event_Types]
  	  FOR INSERT, UPDATE, DELETE
AS  	  
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
UPDATE SITE_Parameters SET [Value] = 1 where parm_Id = 700 and [Value]=0;
