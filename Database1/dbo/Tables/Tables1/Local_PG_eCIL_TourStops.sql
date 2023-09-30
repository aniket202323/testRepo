CREATE TABLE [dbo].[Local_PG_eCIL_TourStops] (
    [Tour_Stop_Id]    INT            IDENTITY (1, 1) NOT NULL,
    [Route_Id]        INT            NOT NULL,
    [Tour_Stop_Desc]  VARCHAR (150)  NOT NULL,
    [Tour_Map_link]   VARCHAR (2000) NULL,
    [Tour_Stop_Order] INT            NULL,
    CONSTRAINT [PK_Local_PG_eCIL_TourStops] PRIMARY KEY CLUSTERED ([Tour_Stop_Id] ASC),
    CONSTRAINT [Local_PG_eCIL_TourStops_FK_Local_PG_eCIL_Routes] FOREIGN KEY ([Route_Id]) REFERENCES [dbo].[Local_PG_eCIL_Routes] ([Route_Id])
);

