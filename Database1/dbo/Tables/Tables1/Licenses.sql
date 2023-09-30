CREATE TABLE [dbo].[Licenses] (
    [License_Id]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [License_Text] VARCHAR (500) NULL,
    CONSTRAINT [Licenses_PK_LicenseId] PRIMARY KEY NONCLUSTERED ([License_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Licenses_IX_LicenseText]
    ON [dbo].[Licenses]([License_Text] ASC);

