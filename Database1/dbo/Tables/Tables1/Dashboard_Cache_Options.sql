CREATE TABLE [dbo].[Dashboard_Cache_Options] (
    [Dashboard_Cache_Option_ID]          INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Cache_Option_Code]        INT           NOT NULL,
    [Dashboard_Cache_Option_Description] VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Dashboard_Cache_Options] PRIMARY KEY CLUSTERED ([Dashboard_Cache_Option_ID] ASC)
);

