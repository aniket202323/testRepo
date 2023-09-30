CREATE TABLE [dbo].[LensDmc] (
    [LensDmcId]      NVARCHAR (255) NOT NULL,
    [Name]           NVARCHAR (255) NULL,
    [DisplayName]    NVARCHAR (255) NULL,
    [r_Public]       BIT            NULL,
    [IconID]         NVARCHAR (255) NULL,
    [Classification] NVARCHAR (255) NULL,
    [Description]    NVARCHAR (255) NULL,
    [Type]           NVARCHAR (255) NULL,
    [Version]        BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([LensDmcId] ASC)
);

