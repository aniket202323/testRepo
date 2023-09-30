CREATE TABLE [dbo].[Performance_Objects] (
    [Description] VARCHAR (200) NOT NULL,
    [Name]        VARCHAR (30)  NOT NULL,
    [Object_Id]   INT           NOT NULL,
    CONSTRAINT [PK_Performance_Objects] PRIMARY KEY NONCLUSTERED ([Object_Id] ASC)
);

