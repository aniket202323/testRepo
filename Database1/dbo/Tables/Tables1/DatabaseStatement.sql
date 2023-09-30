CREATE TABLE [dbo].[DatabaseStatement] (
    [Id]            UNIQUEIDENTIFIER NOT NULL,
    [DisplayName]   NVARCHAR (50)    NULL,
    [Description]   NVARCHAR (255)   NULL,
    [Statement]     NVARCHAR (MAX)   NULL,
    [StatementType] NVARCHAR (255)   NULL,
    [Provider]      NVARCHAR (255)   NULL,
    [Version]       BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DatabaseStatement_DisplayName]
    ON [dbo].[DatabaseStatement]([DisplayName] ASC);

