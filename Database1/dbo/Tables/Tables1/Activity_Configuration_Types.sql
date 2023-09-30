CREATE TABLE [dbo].[Activity_Configuration_Types] (
    [Activity_Config_Type_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [Activity_Config_Type_Desc] VARCHAR (100) NULL,
    [Activity_Type_Id]          INT           NOT NULL,
    CONSTRAINT [ActivityConfigType_PK_ActivityConfigTypeId] PRIMARY KEY CLUSTERED ([Activity_Config_Type_Id] ASC),
    CONSTRAINT [ActivityConfigType_FK_ActivityTypeId] FOREIGN KEY ([Activity_Type_Id]) REFERENCES [dbo].[Activity_Types] ([Activity_Type_Id])
);

