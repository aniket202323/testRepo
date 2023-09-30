CREATE FUNCTION [dbo].[fnLocal_CmnRptScrapDetailByEquipment]
(@strAreaId VARCHAR (100) NULL, @strProdLineId VARCHAR (100) NULL, @strWorkCellId VARCHAR (400) NULL, @vchTimeOption VARCHAR (50) NULL, @dtmStartDateTime DATETIME NULL, @dtmEndDateTime DATETIME NULL, @vchExcludeNPT VARCHAR (3) NULL)
RETURNS 
    @GeneratedTableName TABLE (
        [WED_Id]             INT            NULL,
        [RejectTimeStamp]    DATETIME       NULL,
        [RejectAmount]       INT            NULL,
        [UOM]                VARCHAR (100)  NULL,
        [ValueStream]        VARCHAR (100)  NULL,
        [DeptDesc]           VARCHAR (100)  NULL,
        [PLDesc]             VARCHAR (100)  NULL,
        [PUDesc]             VARCHAR (100)  NULL,
        [WEFaultValue]       VARCHAR (100)  NULL,
        [Location]           VARCHAR (100)  NULL,
        [EquipmentArea]      VARCHAR (100)  NULL,
        [FLDesc]             VARCHAR (100)  NULL,
        [EventReasonName1]   VARCHAR (100)  NULL,
        [EventReasonName2]   VARCHAR (100)  NULL,
        [EventReasonName3]   VARCHAR (100)  NULL,
        [EventReasonName4]   VARCHAR (100)  NULL,
        [CommentIdList]      VARCHAR (1000) NULL,
        [ShiftDesc]          VARCHAR (50)   NULL,
        [CrewDesc]           VARCHAR (50)   NULL,
        [ProductionDay]      VARCHAR (10)   NULL,
        [ProdStatus]         VARCHAR (50)   NULL,
        [ProdCode]           VARCHAR (50)   NULL,
        [ProdDesc]           VARCHAR (200)  NULL,
        [ExecPath]           VARCHAR (100)  NULL,
        [ConstraintWorkCell] INT            NULL)
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END

