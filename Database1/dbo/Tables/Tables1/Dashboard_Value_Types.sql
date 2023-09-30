CREATE TABLE [dbo].[Dashboard_Value_Types] (
    [Dashboard_Value_Type_ID]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Value_Code]      INT           NOT NULL,
    [Dashboard_Value_Type_Desc] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Dashboard_Value_Types] PRIMARY KEY CLUSTERED ([Dashboard_Value_Type_ID] ASC)
);

