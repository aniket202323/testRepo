CREATE FUNCTION [dbo].[fnLocal_RptCenterline_Completion]
(@Equipment VARCHAR (1000) NULL, @CenterlineTypes VARCHAR (1000) NULL, @Teams VARCHAR (1000) NULL, @Shifts VARCHAR (1000) NULL, @TimeWindow VARCHAR (30) NULL, @Start DATETIME NULL, @End DATETIME NULL, @AutoYesNo VARCHAR (3) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [Id]               INT            IDENTITY (1, 1) NOT NULL,
        [PlantName]        NVARCHAR (200) NULL,
        [Line]             NVARCHAR (200) NULL,
        [PUId]             INT            NULL,
        [PugDesc]          NVARCHAR (200) NULL,
        [Team]             NVARCHAR (10)  NULL,
        [Shift]            NVARCHAR (10)  NULL,
        [ProdStatus]       NVARCHAR (200) NULL,
        [Frequency]        NVARCHAR (200) NULL,
        [ResultOn]         DATETIME       NULL,
        [Result]           NVARCHAR (25)  NULL,
        [Lreject]          NVARCHAR (25)  NULL,
        [Lwarning]         NVARCHAR (25)  NULL,
        [Luser]            NVARCHAR (25)  NULL,
        [Target]           NVARCHAR (25)  NULL,
        [UUser]            NVARCHAR (25)  NULL,
        [UWarning]         NVARCHAR (25)  NULL,
        [Ureject]          NVARCHAR (25)  NULL,
        [SamplesTaken]     INT            NULL,
        [SamplesDue]       INT            NULL,
        [FutureSamplesDue] INT            NULL,
        [Defects]          INT            NULL,
        [ProdDesc]         NVARCHAR (200) NULL,
        [VarDesc]          NVARCHAR (200) NULL,
        [VarId]            INT            NULL,
        [ProdCode]         INT            NULL,
        [NextStartDate]    DATETIME       NULL,
        [TestTime]         DATETIME       NULL,
        [AlarmId]          INT            NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

