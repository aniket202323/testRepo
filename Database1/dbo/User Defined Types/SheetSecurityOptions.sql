CREATE TYPE [dbo].[SheetSecurityOptions] AS TABLE (
    [SecurityType]  VARCHAR (30) NULL,
    [DtOption]      INT          NULL,
    [DtpOption]     INT          NULL,
    [DefaultLevel]  INT          NULL,
    [UsersSecurity] INT          NULL,
    [MasterUnit]    INT          NULL,
    [PU_Id]         INT          NULL);

