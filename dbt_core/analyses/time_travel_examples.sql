/* =============================================================================
   Time travel and data recovery demonstration
   The goal is to demonstrate Snowflake's ability to recover from accidental data loss.
   Copy this files contents into a snowflake datasheet and run the queries one by one.
   =============================================================================
*/

USE DATABASE RETAIL_VAULT_DEV;
USE SCHEMA PUBLIC_MARTS;

-- -----------------------------------------------------------------------------
-- STEP 1: Capturing "Before" state
-- Check customer count in AUTOMOBILE segment.
-- -----------------------------------------------------------------------------
SELECT COUNT(*) as original_count 
FROM DIM_CUSTOMER 
WHERE market_segment_raw = 'AUTOMOBILE'; 


-- -----------------------------------------------------------------------------
-- STEP 2: A "disaster" (simulating user error)
-- Accidentally deleting all AUTOMOBILE customers from the segment.
-- -----------------------------------------------------------------------------
DELETE FROM DIM_CUSTOMER 
WHERE market_segment_raw = 'AUTOMOBILE';

-- Verifying that data is gone
SELECT COUNT(*) as count_after_disaster
FROM DIM_CUSTOMER 
WHERE market_segment_raw = 'AUTOMOBILE';


-- -----------------------------------------------------------------------------
-- STEP 3: Time Travel Query
-- Using "AT(OFFSET => ...)" to look 2 minutes into the past.
-- -----------------------------------------------------------------------------
SELECT COUNT(*) as count_in_past
FROM DIM_CUSTOMER 
AT(OFFSET => -120)
WHERE market_segment_raw = 'AUTOMOBILE';


-- -----------------------------------------------------------------------------
-- STEP 4: Restoration
-- Insert deleted data back from the past.
-- -----------------------------------------------------------------------------
INSERT INTO DIM_CUSTOMER
SELECT * FROM DIM_CUSTOMER 
AT(OFFSET => -120)
WHERE market_segment_raw = 'AUTOMOBILE';

-- The Final check
SELECT COUNT(*) as count_restored
FROM DIM_CUSTOMER 
WHERE market_segment_raw = 'AUTOMOBILE';