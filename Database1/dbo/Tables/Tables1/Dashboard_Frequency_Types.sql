CREATE TABLE [dbo].[Dashboard_Frequency_Types] (
    [Dashboard_Frequency_Type_ID]           INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Frequency_Conversion_Factor] INT           NOT NULL,
    [Dashboard_Frequency_Type]              VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Dashboard_Frequency_Types] PRIMARY KEY CLUSTERED ([Dashboard_Frequency_Type_ID] ASC)
);

