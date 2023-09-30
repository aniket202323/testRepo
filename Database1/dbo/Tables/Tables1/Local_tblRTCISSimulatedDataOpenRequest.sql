CREATE TABLE [dbo].[Local_tblRTCISSimulatedDataOpenRequest] (
    [INVENTORYAVAI] VARCHAR (2)  NULL,
    [ALTULQTYUSED]  INT          NULL,
    [MATREQ]        SMALLINT     NOT NULL,
    [STATUS]        VARCHAR (25) NOT NULL,
    [PLNUMB]        VARCHAR (25) NULL,
    [PRDORD]        VARCHAR (25) NOT NULL,
    [REQITM]        VARCHAR (25) NOT NULL,
    [ULQTY]         VARCHAR (25) NOT NULL,
    [REQDAT]        DATETIME     NOT NULL,
    [DEPLOC]        VARCHAR (25) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [TblMaterialRequest_REQDAT]
    ON [dbo].[Local_tblRTCISSimulatedDataOpenRequest]([REQDAT] ASC);

