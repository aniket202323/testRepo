CREATE TYPE [dbo].[UnitsType] AS TABLE (
    [Pu_Id]       INT      NULL,
    [OEEType]     INT      DEFAULT ((0)) NULL,
    [Start_Date1] DATETIME NULL,
    [End_Date1]   DATETIME NULL,
    [Start_Date2] DATETIME NULL,
    [End_Date2]   DATETIME NULL);

