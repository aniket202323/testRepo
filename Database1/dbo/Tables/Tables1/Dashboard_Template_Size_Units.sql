CREATE TABLE [dbo].[Dashboard_Template_Size_Units] (
    [Dashboard_Template_Size_Unit_ID]          INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Template_Size_Unit_Code]        VARCHAR (10) NOT NULL,
    [Dashboard_Template_Size_Unit_Description] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Dashboard_Template_Size_Units] PRIMARY KEY CLUSTERED ([Dashboard_Template_Size_Unit_ID] ASC)
);

