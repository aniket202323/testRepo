CREATE TABLE [dbo].[Dashboard_Template_Launch_Type] (
    [Dashboard_Template_Launch_Type_ID] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Template_Launch_Type]    VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Dashboard_Template_Launch_Type] PRIMARY KEY CLUSTERED ([Dashboard_Template_Launch_Type_ID] ASC)
);

