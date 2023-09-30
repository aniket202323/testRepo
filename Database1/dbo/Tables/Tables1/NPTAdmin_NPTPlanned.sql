CREATE TABLE [dbo].[NPTAdmin_NPTPlanned] (
    [NPTPlanned_Id]   INT      IDENTITY (1, 1) NOT NULL,
    [Path_Id]         INT      NOT NULL,
    [PP_Id]           INT      NOT NULL,
    [Event_Reason_Id] INT      NOT NULL,
    [User_Id]         INT      NULL,
    [Modified_On]     DATETIME NULL,
    CONSTRAINT [PK_NPTAdmin_POPlanned] PRIMARY KEY CLUSTERED ([NPTPlanned_Id] ASC)
);

