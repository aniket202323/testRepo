CREATE TABLE [dbo].[Local_PG_eCIL_Teams] (
    [Team_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [Team_Desc] VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_Teams] PRIMARY KEY CLUSTERED ([Team_Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Local_PG_eCIL_Teams_IX_TeamDesc]
    ON [dbo].[Local_PG_eCIL_Teams]([Team_Desc] ASC);

