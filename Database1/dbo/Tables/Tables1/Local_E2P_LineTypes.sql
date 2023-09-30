CREATE TABLE [dbo].[Local_E2P_LineTypes] (
    [LineTypeId]   INT           IDENTITY (1, 1) NOT NULL,
    [LineTypeDesc] VARCHAR (50)  NOT NULL,
    [UDP]          VARCHAR (200) NOT NULL,
    CONSTRAINT [LocalE2PLineTypes_PK_LineTypeId] PRIMARY KEY CLUSTERED ([LineTypeId] ASC)
);

