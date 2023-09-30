CREATE TABLE [dbo].[Dashboard_Template_Links] (
    [Dashboard_Template_Link_ID]   INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Template_Link_From] INT NOT NULL,
    [Dashboard_Template_Link_To]   INT NOT NULL,
    CONSTRAINT [PK_Dashboard_Template_Links] PRIMARY KEY CLUSTERED ([Dashboard_Template_Link_ID] ASC)
);

