CREATE TABLE [dbo].[ScannerDescription] (
    [Id]              INT            NOT NULL,
    [ScannerIP]       NVARCHAR (100) NULL,
    [ScannerRowType]  INT            NULL,
    [ScannerCharType] INT            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

