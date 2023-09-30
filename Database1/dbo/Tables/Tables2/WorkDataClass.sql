CREATE TABLE [dbo].[WorkDataClass] (
    [WorkDataClassClassId] UNIQUEIDENTIFIER NOT NULL,
    [Name]                 NVARCHAR (255)   NULL,
    [Description]          NVARCHAR (255)   NULL,
    [Version]              BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([WorkDataClassClassId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WorkDataClass_Name]
    ON [dbo].[WorkDataClass]([Name] ASC);

