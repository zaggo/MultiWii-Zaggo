// BLINKEN - (Contribution by Zaggo. Idea by Captain Ixi and Zaggo)
// Use the copter's LEDs (usually LED strips attached to the arms) as status display
// This option currently supports TRI, QUADX and QUADP configurations. 
// Connect 3 (TRI) or 4 (QUADX/QUADP) LED (Strips) with help of a driver chip (e.g. UDN2981A) to the
// flight controller.
// For TRI configuration, use pins 31 (left), 32 (right) and 33 (back). Buzzer pin stays pin 30.
// For QUADP configuration, use pins 30 (front), 31 (right), 32 (back) and 33 (left). Buzzer pin is re-assigned to digital pin 8
// For QUADX configuration, ise üins 30 (left front), 31 (right front), 32 (right back), 33 (left back). Buzzer pin is re-assigned to digital pin 8
// See def.h for more details.

#ifdef BLINKEN

//////////////////////////
// Verbose, Log and Trace
// For development only!
/////////////////////////

//#define VERBOSE

#ifdef VERBOSE
  static uint32_t lastBlinkenState = 0;
  static char kStateName [kBlinkenPowerUpSequence+1][40] = {
    "kBlinkenUnchanged ",
    "kBlinkenDefault ",
    "kBlinkenAllOn ",
    "kBlinkenAllOff ",
    "kBlinkenBackOnly ",
    "kBlinkenGPSActive ",
    "kBlinkenGPSNoFix ",
    "kBlinkenCalibrationSequence ",
    "kBlinkenBatWarning1 ",
    "kBlinkenBatWarning2 ",
    "kBlinkenBatWarning3 ",
    "kBlinkenFailSafe1 ",
    "kBlinkenFailSafe2 ",
    "kBlinkenPowerUpSequence "
  };

  #define LOGBLINKENSTATE if(lastBlinkenState!=blinkenState) { lastBlinkenState = blinkenState; Serial.print("Blinken: "); if(blinkenState>=0 && blinkenState<=kBlinkenPowerUpSequence) Serial.print(kStateName[blinkenState]); Serial.println(blinkenState, DEC); }
  #define TRACEBLINKEN(x) Serial.print("Blinken: "); Serial.println(x); 
#else
  #define LOGBLINKENSTATE
  #define TRACEBLINKEN(x)
#endif

//////////////////////////////////
// End Verbose, Log and Trace
//////////////////////////////////

static uint32_t blinkenBackToDefault = 0;

void setBlinkenState(uint16_t state)
{
    // This function only escalates the blinkenState
    // A less important state cannot overwrite a more important state!
    if(state>blinkenState)
      blinkenState = state;
}

void handleBlinkenState()
{
  if(blinkenBackToDefault>0)
  {
    if(currentTime>blinkenBackToDefault)
    {
      blinkenBackToDefault = 0;
      setBlinkenState(kBlinkenDefault);
      TRACEBLINKEN("backToDefault");
    }
  }
  
  LOGBLINKENSTATE;
  
  switch(blinkenState)
  {
    case kBlinkenDefault: 
      BLINKEN_ALL_ON;  // TODO: Depending on settings or RC might be kBlinkenBackOnly or kBlinkenAllOff...
      blinkenState=kBlinkenUnchanged; 
      break;
    case kBlinkenAllOn: 
      BLINKEN_ALL_ON; 
      blinkenState=kBlinkenUnchanged; 
      break;
    case kBlinkenAllOff: 
      BLINKEN_ALL_OFF; 
      blinkenState=kBlinkenUnchanged; 
      break;
    case kBlinkenBackOnly: 
      BLINKEN_BACK_ONLY; 
      blinkenState=kBlinkenUnchanged; 
      break;
    case kBlinkenPowerUpSequence: 
      blinkenPowerUpSequence(); // This is a special case. Reset to kBlinkenDefault inside blinkenPowerUpSequence when ready.
      break;
    case kBlinkenCalibrationSequence: 
      blinkenRotate(); 
      blinkenState=kBlinkenDefault; 
      break;
    case kBlinkenBatWarning1: 
      blinkenBatWarn(1); 
      blinkenState=kBlinkenDefault; 
      break;
    case kBlinkenBatWarning2: 
      blinkenBatWarn(2); 
      blinkenState=kBlinkenDefault; 
      break;
    case kBlinkenBatWarning3: 
      blinkenBatWarn(3); 
      blinkenState=kBlinkenDefault; 
      break;
    case kBlinkenFailSafe1: 
      blinkenFailsafe1();
      blinkenState=kBlinkenDefault; 
      break;
    case kBlinkenFailSafe2: 
      blinkenBatWarn(3);
      blinkenState=kBlinkenDefault; 
      break;
    case kBlinkenGPSActive:
      blinkenRotate();
      blinkenState=kBlinkenDefault;
      break;
    case kBlinkenGPSNoFix:
      blinkenGPSNoFix();
      blinkenState=kBlinkenDefault;
      break;
  }
}

void blinkenTrimFront()
{
    BLINKEN_ALL_OFF
    blinkenState = kBlinkenUnchanged;
    #if defined(TRI) || defined(QUADX)
      BLINKEN1_ON
      BLINKEN2_ON
    #else
      BLINKEN1_ON
    #endif
    blinkenBackToDefault = currentTime+750000;
}

void blinkenTrimLeft()
{
    BLINKEN_ALL_OFF
    blinkenState = kBlinkenUnchanged;
    #if defined(TRI)
      BLINKEN1_ON
    #elif defined(QUADX)
      BLINKEN1_ON
      BLINKEN4_ON
    #else
      BLINKEN4_ON
    #endif
    blinkenBackToDefault = currentTime+750000;
}

void blinkenTrimRight()
{
    BLINKEN_ALL_OFF
    blinkenState = kBlinkenUnchanged;
    #if defined(TRI)
      BLINKEN2_ON
    #elif defined(QUADX)
      BLINKEN2_ON
      BLINKEN3_ON
    #else
      BLINKEN2_ON
    #endif
    blinkenBackToDefault = currentTime+750000;
}

void blinkenTrimBack()
{
    BLINKEN_ALL_OFF
    blinkenState = kBlinkenUnchanged;
    #if defined(TRI)
      BLINKEN3_ON
    #elif defined(QUADX)
      BLINKEN3_ON
      BLINKEN4_ON
    #else
      BLINKEN3_ON
    #endif
    blinkenBackToDefault = currentTime+750000;
}

void blinkenPowerUpSequence()
{
  static uint32_t blinkenPowerUpTime=0;
  static uint8_t  blinkenPowerUpPhase=0;  
  static uint8_t  blinkenPowerUpLoop=0;
  if(currentTime>blinkenPowerUpTime)
  {
    blinkenPowerUpTime=currentTime+100000;
#if defined(TRI)    
    switch(blinkenPowerUpPhase++)
    {
    case 0: 
      BLINKEN1_ON
        blinkenPowerUpLoop=0;
      break;
    case 1: 
      BLINKEN2_ON
        break;
    case 2: 
      BLINKEN3_ON
        break;      
    case 3: 
      BLINKEN1_OFF
        break;
    case 4: 
      BLINKEN1_ON
        BLINKEN2_OFF
        break;
    case 5: 
      BLINKEN2_ON
        BLINKEN3_OFF
        break;
    case 6: 
      BLINKEN3_ON
        BLINKEN1_OFF
        if(++blinkenPowerUpLoop<3)
        blinkenPowerUpPhase=4;
      break;
    case 7: 
      blinkenState=kBlinkenDefault;
      blinkenPowerUpPhase=0;
      break;
    }
#else // QUAD
    switch(blinkenPowerUpPhase++)
    {
    case 0: 
      BLINKEN1_ON
      blinkenPowerUpLoop=0;
      break;
    case 1: 
      BLINKEN2_ON
      break;
    case 2: 
      BLINKEN3_ON
      break;      
    case 3: 
      BLINKEN4_ON
      break;      
    case 4: 
      BLINKEN1_OFF
      break;
    case 5: 
      BLINKEN1_ON
      BLINKEN2_OFF
      break;
    case 6: 
      BLINKEN2_ON
      BLINKEN3_OFF
      break;
    case 7: 
      BLINKEN3_ON
      BLINKEN4_OFF
      break;
    case 8: 
      BLINKEN4_ON
      BLINKEN1_OFF
      if(++blinkenPowerUpLoop<3)
        blinkenPowerUpPhase=4;
      break;
    case 9: 
      blinkenState=kBlinkenDefault;
      blinkenPowerUpPhase=0;
      break;
    }
#endif
  }
}

void blinkenRotate()
{
  static uint32_t blinkenRotationTime=0;
  static uint8_t  blinkenRotationPhase=0;

  if(currentTime>blinkenRotationTime)
  {
    switch(blinkenRotationPhase)
    {
    case 0: 
      BLINKEN_ALL_BUT_1; 
      break;
    case 1: 
      BLINKEN_ALL_BUT_2; 
      break;
    case 2: 
      BLINKEN_ALL_BUT_3; 
      break;
    case 3: 
      BLINKEN_ALL_BUT_4; 
      break;
    }
    blinkenRotationPhase=(blinkenRotationPhase+1)%BLINKEN_COUNT;
    blinkenRotationTime=currentTime+150000;
  }
}

void blinkenGPSNoFix()
{
  static uint32_t blinkenTime=0;
  static uint8_t blinkenPhase=0;
  
  if(currentTime>blinkenTime)
  {
    switch(blinkenPhase++)
    {
      case 0: 
        BLINKEN_ALL_OFF
        blinkenTime=currentTime+100000;
        break;
      case 1:
        BLINKEN_ALL_ON
        blinkenTime=currentTime+120000;
        break;
      case 2:
        BLINKEN_ALL_OFF
        blinkenTime=currentTime+100000;
        break;
      case 3:
        BLINKEN_ALL_ON
        blinkenTime=currentTime+120000;
        break;
      case 4:
        BLINKEN_ALL_OFF
        blinkenTime=currentTime+100000;
        break;
      case 5:
        BLINKEN_ALL_ON
        blinkenTime=currentTime+1000000;
        blinkenPhase=0;
        break;
    }
  }
}

void blinkenFailsafe1()
{
  static uint32_t blinkenTime=0;
  static uint8_t blinkenPhase=0;  
  static uint8_t blinkenLoop=0;
  
  // Blink SOS
  if(currentTime>blinkenTime)
  {
    switch(blinkenPhase++)
    {
      case 0: 
        BLINKEN_ALL_OFF
        blinkenTime=currentTime+100000;
        break;
      case 1:
        BLINKEN_ALL_ON
        if(++blinkenLoop>2) {
          blinkenTime=currentTime+160000;
          blinkenLoop=0;
        }
        else {
          blinkenPhase=0;
          blinkenTime=currentTime+120000;
        }
        break;
      case 2:
        BLINKEN_ALL_OFF
        blinkenTime=currentTime+100000;
        break;
      case 3:
        BLINKEN_ALL_ON
        blinkenTime=currentTime+800000;
        blinkenPhase=0;
        if(++blinkenLoop>2) {
          blinkenLoop=0;
          blinkenPhase=0;
        }
        else
          blinkenPhase=2;
       break;
    }
  }
}

void blinkenBatWarn(int warningStage)
{
  static uint32_t blinkenTime=0;
  static uint8_t blinkenWarnOn=0;

  uint32_t flashOnTime=0;
  uint32_t flashOffTime=0;
  switch(warningStage)
  {
  case 1:
    flashOnTime=1000000;
    flashOffTime=500000;
    break;
  case 2:
    flashOnTime= 400000;
    flashOffTime=400000;    
    break;
  case 3:
    flashOnTime= 150000;
    flashOffTime=150000;    
    break;
  }
  if(flashOnTime>0)
  {
    if(currentTime>blinkenTime)
    {
      if(blinkenWarnOn)
      {
        blinkenTime=currentTime+flashOffTime;
        blinkenWarnOn=0;
        BLINKEN_ALL_OFF;
      }
      else
      {
        blinkenTime=currentTime+flashOnTime;
        blinkenWarnOn=1;
        BLINKEN_ALL_ON;      
      }
    }
  }
}
#endif

