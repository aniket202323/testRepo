CREATE TABLE [dbo].[Local_AMgrVarSpecCache] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [TimeStamp] DATETIME     NOT NULL,
    [VarID]     INT          NOT NULL,
    [ProdID]    INT          NOT NULL,
    [StartTime] DATETIME     NULL,
    [EndTime]   DATETIME     NULL,
    [LRL]       VARCHAR (25) NULL,
    [LWL]       VARCHAR (25) NULL,
    [Target]    VARCHAR (25) NULL,
    [UWL]       VARCHAR (25) NULL,
    [URL]       VARCHAR (25) NULL
);

