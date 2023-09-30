CREATE TABLE [dbo].[Local_PG_eCIL_Routes] (
    [Route_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [Route_Desc] VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_Routes] PRIMARY KEY CLUSTERED ([Route_Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Local_PG_eCIL_Routes_IX_RouteDesc]
    ON [dbo].[Local_PG_eCIL_Routes]([Route_Desc] ASC);

