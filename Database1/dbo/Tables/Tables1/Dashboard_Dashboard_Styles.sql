CREATE TABLE [dbo].[Dashboard_Dashboard_Styles] (
    [Dashboard_Dashboard_Style_ID] INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Dashboard_Style]    CHAR (100) NOT NULL,
    CONSTRAINT [PK_Dashboard_Dashboard_Styles] PRIMARY KEY NONCLUSTERED ([Dashboard_Dashboard_Style_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Dashboard_Styles]
    ON [dbo].[Dashboard_Dashboard_Styles]([Dashboard_Dashboard_Style_ID] ASC);

