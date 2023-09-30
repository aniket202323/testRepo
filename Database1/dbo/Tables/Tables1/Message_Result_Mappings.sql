CREATE TABLE [dbo].[Message_Result_Mappings] (
    [Message_Result_Mapping_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ColumnIndex]               INT           NOT NULL,
    [PropertyName]              VARCHAR (255) NOT NULL,
    [ResultPropertyName]        VARCHAR (255) NULL,
    [Reverse]                   BIT           CONSTRAINT [MessageResultMappings_DF_Reverse] DEFAULT ((0)) NULL,
    [TypeId]                    INT           NOT NULL,
    CONSTRAINT [MessageResultMappings_PK_MessageResultMappingId] PRIMARY KEY NONCLUSTERED ([Message_Result_Mapping_Id] ASC),
    CONSTRAINT [MessageResultMapping_UC_TypeIdColumnIndex] UNIQUE CLUSTERED ([TypeId] ASC, [ColumnIndex] ASC)
);

