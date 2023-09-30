CREATE TYPE [dbo].[FrmDBTimeTable] AS TABLE (
    [InputTime]      DATETIME      NULL,
    [OutputTimeZone] VARCHAR (200) NULL,
    [DBTimeZone]     VARCHAR (200) NULL,
    [ConvertedTime]  DATETIME      NULL);

