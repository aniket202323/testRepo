CREATE TABLE [dbo].[Local_PG_MESWebService_CommandType] (
    [Command_Type_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [Command_Type_Desc] VARCHAR (255) NOT NULL,
    [SP_Name]           VARCHAR (255) NULL,
    [Instance_Id]       INT           NOT NULL,
    [Is_Active]         BIT           CONSTRAINT [LocalPGMESWebServiceCommandType_DF_IsActive] DEFAULT ((1)) NOT NULL,
    [Is_Reprocessable]  BIT           CONSTRAINT [LocalPGMESWebServiceCommandType_DF_IsTransaction] DEFAULT ((1)) NOT NULL,
    [Reprocess_Delay]   INT           NULL,
    CONSTRAINT [LocalPGMESWebServiceCommandType_PK_CommandTypeId] PRIMARY KEY CLUSTERED ([Command_Type_Id] ASC),
    CONSTRAINT [LocalPGMESWebServiceCommandType_FK_InstanceId] FOREIGN KEY ([Instance_Id]) REFERENCES [dbo].[Local_PG_MESWebService_Instances] ([Instance_Id]),
    CONSTRAINT [LocalPGMESWebServiceCommandType_UQ_CommandTypeDescInstanceId] UNIQUE NONCLUSTERED ([Command_Type_Desc] ASC, [Instance_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalPGMESWebServiceCommandType_IDX_CommandTypeDesc]
    ON [dbo].[Local_PG_MESWebService_CommandType]([Command_Type_Desc] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPGMESWebServiceCommandType_IDX_InstanceId]
    ON [dbo].[Local_PG_MESWebService_CommandType]([Instance_Id] ASC);

