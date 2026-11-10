-- Final Project for Advanced SQL
    -- Brynn Crouthamel

-- Get the watchlist for a certain profile
CREATE PROCEDURE GET_WATCHLIST
        @Profile_ID varchar(50)
    AS
    BEGIN
        SELECT C.CON_TITLE AS 'Watch List'
        FROM WATCHED W
        JOIN CONTENT C
        ON W.CON_ID = C.CON_ID
        WHERE PRO_ID = @Profile_ID
        GROUP BY CON_TITLE;
    END
GO

-- Find profiles whose accounts have not watched anything in the past 30 days.
CREATE PROCEDURE FIND_INACTIVE_ACCOUNTS
    AS
    BEGIN
        DECLARE @ACC_ID VARCHAR(50)
        DECLARE @ACC_NAME VARCHAR(50)
        DECLARE @ACC_EMAIL VARCHAR(50);

        DECLARE INACTIVE_ACCOUNTS_CURSOR CURSOR FOR
            SELECT A.ACC_ID, A.ACC_NAME, A.ACC_EMAIL 
        FROM ACCOUNT A
        JOIN PROFILE P
        ON A.ACC_ID = P.ACC_ID
        LEFT JOIN WATCHED W
        ON P.PRO_ID = W.PRO_ID
        AND W.WATCHED_DATE >= DATEADD(DAY, -30, GETDATE())
        GROUP BY A.ACC_ID, A.ACC_NAME, A.ACC_EMAIL 
        HAVING COUNT(W.CON_ID) = 0;

    OPEN INACTIVE_ACCOUNTS_CURSOR;
    FETCH NEXT FROM INACTIVE_ACCOUNTS_CURSOR INTO @ACC_ID, @ACC_NAME, @ACC_EMAIL;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO MAILING_LIST (ACC_ID, MESSAGE, DATE_SENT)
        VALUES (
            @ACC_ID,
            'There has been no activity on your account for the past 30 days.',
            GETDATE()
        );

        FETCH NEXT FROM INACTIVE_ACCOUNTS_CURSOR INTO @ACC_ID, @ACC_NAME, @ACC_EMAIL;
    END
    CLOSE INACTIVE_ACCOUNTS_CURSOR;
    DEALLOCATE INACTIVE_ACCOUNTS_CURSOR;
    END
GO
    
-- Shows the top rated show in the genre based on ratings given by the users
CREATE PROCEDURE TOP_RATED_SHOW_IN_GENRE
    AS 
    BEGIN
        WITH ALL_RATINGS AS (
        SELECT 
            C.CON_ID,
            C.CON_TITLE,
            C.CON_GENRE,
            AVG(W.PERS_RATING) AS OVERALL_RATING,
            ROW_NUMBER() OVER (
                PARTITION BY C.CON_GENRE
                ORDER BY AVG(W.PERS_RATING) DESC
            ) AS GENRE_RANKING
        FROM WATCHED W
        JOIN CONTENT C
            ON W.CON_ID = C.CON_ID
        GROUP BY C.CON_ID, C.CON_TITLE, C.CON_GENRE
        )

        SELECT CON_ID,
            CON_TITLE,
            CON_GENRE
        FROM ALL_RATINGS
        WHERE GENRE_RANKING = 1;
    END
GO

-- Deletes an account, including all associated profiles, and records in watched
CREATE PROCEDURE DELETE_ACCOUNT
    @DELETED_ACC_ID varchar(50)
AS
BEGIN
BEGIN TRANSACTION

    DELETE W 
    FROM WATCHED W
    JOIN PROFILE P 
    ON P.PRO_ID = W.PRO_ID
    WHERE P.ACC_ID = @DELETED_ACC_ID;

    DELETE FROM PROFILE
    WHERE ACC_ID = @DELETED_ACC_ID;

    DELETE FROM ACCOUNT
    WHERE ACC_ID = @DELETED_ACC_ID;

COMMIT TRANSACTION;
END
GO


 