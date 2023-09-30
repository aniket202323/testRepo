CREATE TABLE [dbo].[StoredImageDmc] (
    [r_Key]     NVARCHAR (255) NOT NULL,
    [Filename]  NVARCHAR (255) NULL,
    [Datetime]  DATETIME       NULL,
    [ImageData] IMAGE          NULL,
    [Version]   BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([r_Key] ASC)
);

