CREATE TABLE [dbo].[PersonnelLocation] (
    [IdLocation]  UNIQUEIDENTIFIER NOT NULL,
    [Name]        NVARCHAR (255)   NULL,
    [Description] NVARCHAR (255)   NULL,
    [Type]        INT              NULL,
    [IPAddress]   NVARCHAR (255)   NULL,
    [Version]     BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([IdLocation] ASC)
);

