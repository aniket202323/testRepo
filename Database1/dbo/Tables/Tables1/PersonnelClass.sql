CREATE TABLE [dbo].[PersonnelClass] (
    [PersonnelClassName] NVARCHAR (200)   NOT NULL,
    [Id]                 UNIQUEIDENTIFIER NULL,
    [Description]        NVARCHAR (255)   NULL,
    [Private]            BIT              NULL,
    [Version]            BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([PersonnelClassName] ASC)
);


GO
ALTER TABLE [dbo].[PersonnelClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_PersonnelClass_Id]
    ON [dbo].[PersonnelClass]([Id] ASC);

