CREATE TABLE [dbo].[Local_E2P_LineTypeDirectory] (
    [LTD_Id]       INT           IDENTITY (1, 1) NOT NULL,
    [SubSector]    VARCHAR (50)  NOT NULL,
    [GlobalForm]   VARCHAR (50)  NOT NULL,
    [LineType]     INT           NOT NULL,
    [BOMComponent] VARCHAR (100) NULL,
    CONSTRAINT [LocalE2PLineTypeDirectory_PK_LTDId] PRIMARY KEY CLUSTERED ([LTD_Id] ASC)
);

