#ifndef __CHOPPA_V8_HOSTING_MQH__
#define __CHOPPA_V8_HOSTING_MQH__

// CHOPPA V8 HOSTING telemetry helper.
// Add the URL to MT5:
// Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL
//
// This helper sends a compact JSON snapshot to:
//   <BaseURL>/api/telemetry
//
// IMPORTANT:
// 1. Replace BaseURL with your hosted CHOPPA V8 HOSTING address.
// 2. Replace ApiKey with your private API key.
// 3. Do not publish the key publicly.

string ChoppaHostingBaseURL = "http://127.0.0.1:8080";
string ChoppaHostingApiKey  = "CHOPPA_CHANGE_ME";

string JsonEscape(string value)
{
   StringReplace(value, "\\", "\\\\");
   StringReplace(value, "\"", "\\\"");
   StringReplace(value, "\r", "\\r");
   StringReplace(value, "\n", "\\n");
   return value;
}

string JsonNum(double value)
{
   return DoubleToString(value, 8);
}

string JsonBool(bool value)
{
   return value ? "true" : "false";
}

string ChoppaHostingTelemetryJson()
{
   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin     = AccountInfoDouble(ACCOUNT_MARGIN);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   double spreadPoints = 0.0;
   if(point > 0)
      spreadPoints = (ask - bid) / point;

   string tf = EnumToString((ENUM_TIMEFRAMES)_Period);
   string slMode = (SL_Mode == 1 ? "ATR" : "SWING");

   string json = "{";
   json += "\"bot\":{";
   json += "\"name\":\"CHOPPA V8 BOT\",";
   json += "\"version\":\"3.10\",";
   json += "\"status\":\"ONLINE\",";
   json += "\"magicNumber\":" + IntegerToString(MagicNumber) + ",";
   json += "\"maxOpenTrades\":" + IntegerToString(MaxOpenTrades) + ",";
   json += "\"tradingHoursRestriction\":false,";
   json += "\"debugMode\":" + JsonBool(DebugMode) + ",";
   json += "\"symbol\":\"" + JsonEscape(_Symbol) + "\",";
   json += "\"timeframe\":\"" + JsonEscape(tf) + "\",";
   json += "\"broker\":\"" + JsonEscape(AccountInfoString(ACCOUNT_COMPANY)) + "\",";
   json += "\"server\":\"" + JsonEscape(AccountInfoString(ACCOUNT_SERVER)) + "\"";
   json += "},";

   json += "\"settings\":{";
   json += "\"fastEMA\":" + IntegerToString(FastEMA) + ",";
   json += "\"slowEMA\":" + IntegerToString(SlowEMA) + ",";
   json += "\"pullbackBars\":" + IntegerToString(PullbackBars) + ",";
   json += "\"slMode\":" + IntegerToString(SL_Mode) + ",";
   json += "\"slModeName\":\"" + slMode + "\",";
   json += "\"atrPeriod\":" + IntegerToString(ATR_Period) + ",";
   json += "\"atrMultiplier\":" + JsonNum(ATR_Multiplier) + ",";
   json += "\"riskReward\":" + JsonNum(RiskReward) + ",";
   json += "\"useFixedLot\":" + JsonBool(UseFixedLot) + ",";
   json += "\"fixedLotSize\":" + JsonNum(FixedLotSize) + ",";
   json += "\"riskPercent\":" + JsonNum(RiskPercent);
   json += "},";

   json += "\"account\":{";
   json += "\"balance\":" + JsonNum(balance) + ",";
   json += "\"equity\":" + JsonNum(equity) + ",";
   json += "\"freeMargin\":" + JsonNum(freeMargin) + ",";
   json += "\"margin\":" + JsonNum(margin) + ",";
   json += "\"currency\":\"" + JsonEscape(AccountInfoString(ACCOUNT_CURRENCY)) + "\"";
   json += "},";

   json += "\"market\":{";
   json += "\"bid\":" + JsonNum(bid) + ",";
   json += "\"ask\":" + JsonNum(ask) + ",";
   json += "\"spreadPoints\":" + JsonNum(spreadPoints) + ",";
   json += "\"digits\":" + IntegerToString(digits) + ",";
   json += "\"point\":" + JsonNum(point);
   json += "},";

   // Open positions for this symbol + Magic Number.
   json += "\"positions\":[";
   bool first = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      string symbol = PositionGetString(POSITION_SYMBOL);
      long magic = PositionGetInteger(POSITION_MAGIC);

      if(symbol != _Symbol || magic != MagicNumber)
         continue;

      if(!first) json += ",";
      first = false;

      long posType = PositionGetInteger(POSITION_TYPE);
      string side = (posType == POSITION_TYPE_BUY ? "BUY" : "SELL");

      json += "{";
      json += "\"ticket\":\"" + IntegerToString((long)ticket) + "\",";
      json += "\"symbol\":\"" + JsonEscape(symbol) + "\",";
      json += "\"type\":\"" + side + "\",";
      json += "\"volume\":" + JsonNum(PositionGetDouble(POSITION_VOLUME)) + ",";
      json += "\"openPrice\":" + JsonNum(PositionGetDouble(POSITION_PRICE_OPEN)) + ",";
      json += "\"currentPrice\":" + JsonNum(PositionGetDouble(POSITION_PRICE_CURRENT)) + ",";
      json += "\"sl\":" + JsonNum(PositionGetDouble(POSITION_SL)) + ",";
      json += "\"tp\":" + JsonNum(PositionGetDouble(POSITION_TP)) + ",";
      json += "\"profit\":" + JsonNum(PositionGetDouble(POSITION_PROFIT)) + ",";
      json += "\"time\":\"" + TimeToString((datetime)PositionGetInteger(POSITION_TIME), TIME_DATE|TIME_SECONDS) + "\"";
      json += "}";
   }
   json += "]";

   json += "}";
   return json;
}

bool ChoppaHostingSendTelemetry()
{
   string url = ChoppaHostingBaseURL + "/api/telemetry";
   string headers =
      "Content-Type: application/json\r\n"
      "X-CHOPPA-API-KEY: " + ChoppaHostingApiKey + "\r\n";

   string json = ChoppaHostingTelemetryJson();

   char post[];
   char result[];
   string resultHeaders;

   StringToCharArray(json, post, 0, StringLen(json), CP_UTF8);

   ResetLastError();

   int code = WebRequest(
      "POST",
      url,
      headers,
      5000,
      post,
      result,
      resultHeaders
   );

   if(code == -1)
   {
      Print("[CHOPPA HOSTING] WebRequest failed. Error=", GetLastError());
      return false;
   }

   if(code < 200 || code >= 300)
   {
      Print("[CHOPPA HOSTING] Server returned HTTP ", code);
      return false;
   }

   return true;
}

#endif
