####################################
## Reproduction of "Fog-Assisted Caching..." paper ##
## Case C: Power Consumption with Fully Renewable Powered CDCs and Solar Powered FDCs with ESDs
## Version 7 ##
## Model ##
## Kamal Gamir-Shahin ##
## 26/04/2021 ##
####################################

# SET DECLARATION #
set N;					# Set of all nodes
set Nm{N} within N;		# Set neighbouring nodes (n to m)
set T;					# Set of hours in a day
set WR;					# Set of Wavelength Rates (in Gbps)
set CDC within N;		# Set of Cloud Data Centres (which nodes they are located)
set S := 1 .. 89;		# Set of servers in a fog data centre

# PARAMETER DECLARATION #
param SS >= 0;						# The duration between consecutive hours in T 
param Dmn{m in N, n in N} >= 0;		# The physical distance between connected nodes m and n (in km)	
param SPdt{d in N, t in T} >= 0;  	# Solar power availability per m^2 in W at each node (see Table 2. in paper)   
param Bm >= 0;						# Line rate of an aggregation port in Gbps
param W > 0; 						# Number of wavelengths in a fibre
param DA > 0;						# Span between two neighbouring EDFAs

param Br{r in WR} >= 0; # Line rate at wavelength rate r

param Amn{m in N, n in Nm[m]} = ceil(Dmn[m,n]/DA - 1) + 2;		# Number of EDFAs in the physical link (m,n)
param Rr{r in WR} >= 0;											# Reach of regenerators at a wavelength rate r
param Gmnr{m in N, n in Nm[m], r in WR} = ceil(Dmn[m,n]/Rr[r]);	# Number of regenerators in the physical link at wavelength r							

param PRr{r in WR} >= 0; 	# Power consumption of a router port at wavelength rate r
param PTr{r in WR} >= 0;	# Power consumption of a tranponder at wavelength rate r
param PGr{r in WR} >= 0; 	# Power consumption of a regenerator at wavelength rate r

param VoDcdt{c in CDC, d in N, t in T} >= 0; # Demands from CDC c to node d at time T

param PRm >= 0;	# Power consumption of an aggregation router port
param POm >= 0; # Power consumption of an optical switch at core mode m
param PE >= 0;	# Power consumption of an EDFA
param PS >= 0;	# Power consumption of a metro Ethernet switch port at a rate of 40 Gbps
param Pcs >= 0;	# Power consumption of a content centre per Gbps
param Cs >= 0;	# Capacity of a content server in Gbps

param PUEc >= 0; # Power Usage Effectiveness of Cloud Data Centres
param PUEf >= 0; # Power Usage Effectiveness of Fog Data Centres
param PUEn >= 0; # Power Usage Effectiveness of Core, metro and access networking equipment

param Zcdc >= 0; # Ratio to account for networking equipment power consumption in CDCs
param Zfdc >= 0; # Ratio to account for networking equipment power consumption in FDCs

param Polt >= 0; 	# Power consmuption of an OLT (Optical Line Terminal)
param Colt >= 0;	# Total capacity of links between OLT and metro network
param Cfdc >= 0; 	# Total capacity of links between OLT annd fog data centre


# Solar Energy Parameters #
param SSC >= 0; 	# Size of solar cell in (m^2)
param Emax >= 0; 	# Battery maximum capacity (in kWh)
param Alpha >= 0; 	# Charging efficiency during S(Alpha)
param Beta >= 0;	# Charging efficiency during S(Beta)

##################################
# VARIABLE DECLARATION #
var Lcd_ijt{c in CDC, d in N, i in N, j in N, t in T : c <> d} >= 0;				# Traffic between node pair (c,d) passing through (i, j) at a time T
var Cijrt{i in N, j in N, r in WR, t in T : i <> j} >= 0; 							# Number of wavelengths at rate r on the virtual link (i,j)
var wmn_ijrt{m in N, n in Nm[m], i in N, j in N, r in WR, t in T : i <> j} >= 0; 	# No. of WLs at rate r in virtual link in the physical link m.n
var Fmnt{m in N, n in Nm[m], t in T} >= 0; 											# Number of fibres used on the link (m,n) at time T
var Wmnrt{m in N, n in Nm[m], r in WR, t in T} >= 0; 								# Total number of wavelengths at rate r in the physical link (m,n)

var CCQct{c in N, t in T} >= 0;	# Number of aggregation ports required to connect core node c with the CDC in c at time t
var CMQdt{d in N, t in T} >= 0;	# Number of aggregation ports required to connect core node d with the metro network in d at time t
var MCQct{c in N, t in T} >= 0;	# Number of aggregation ports required to connect the metro network with the CDC c at time t
var MAQdt{d in N, t in T} >= 0; # Number of aggregation ports required to connect the metro network in d at time t

var VoDCcdt{c in CDC, d in N, t in T} >= 0; # Demands by users in node d that are served by CDC c at time t
var VoDFcdt{c in CDC, d in N, t in T} >= 0; # Demands by users in node d from CDC c, instead served by FDC d at time t

var OLTdt{d in N, t in T} >= 0;	# Number of OLTs required in node d to accomodate VoD demands at time T

var VoDFSdst{d in N, s in S, t in T} >= 0; 	# Demands served in FDC d by server s powered by solar at time t
var VoDFBdst{d in N, s in S, t in T} >= 0;	# Demands served in FDC d by server s powered by brown sources at time t
var VoDFEdst{d in N, s in S, t in T} >= 0;	# Demands served in FDC d by server s powered by stored solar power at time t

var Edt{d in N, t in T} >= 0;	# Energy stored in the battery at FDC d at time t
var RSdt{d in N, t in T} >= 0;	# Energy to be charged in the battery from the surplus renewable energy at FDC d at time t
var EDdt{d in N, t in T} >= 0;	# Energy to be discharged from the battery to the FDC d at time t

# CUSTOM VARIABLES #
var CDCserved{d in N} = sum{c in CDC, t in T} VoDCcdt[c,d,t]; # Volume of cloud served VoD traffic
var FDCserved{d in N} = sum{c in CDC, t in T} VoDFcdt[c,d,t] * OLTdt[d,t]; # Volume of fog served VoD traffic

# Ratios of traffic delivered by CDC and FDC to total traffic demands
var CDCratio{d in N} = (sum{c in CDC, t in T} VoDCcdt[c,d,t]) / sum{c in CDC, t in T} VoDcdt[c,d,t];
var FDCratio{d in N} = (sum{c in CDC, t in T} VoDFcdt[c,d,t] * OLTdt[d,t]) / sum{c in CDC, t in T} VoDcdt[c,d,t];

var CDCB{t in T} = sum{c in CDC, d in N} VoDCcdt[c,d,t];
var FDCB{t in T} = sum{d in N, s in S} VoDFBdst[d,s,t] * OLTdt[d,t];
var FDCS{t in T} = sum{d in N, s in S} VoDFSdst[d,s,t] * OLTdt[d,t];
var FDCE{t in T} = sum{d in N, s in S} VoDFEdst[d,s,t] * OLTdt[d,t];

var PtIP{t in T} = # Pt(IP) IP routers under optical bypass:		
		sum{i in N} PRm * (CCQct[i,t] + CMQdt[i,t]) +
		sum{i in N, j in N, r in WR : i <> j} PRr[r] * Cijrt[i,j,r,t];
		
var PtT{t in T} = # Pt(T) Transponders:
		sum{m in N, n in Nm[m], r in WR} PTr[r] * Wmnrt[m,n,r,t];

param PtO{t in T} = # PT(O) Optical switches:
		sum{m in N} POm;

var PtE{t in T} = # Pt(E) EDFAs:
		PE * sum{m in N} sum{n in Nm[m]} Amn[m,n] * Fmnt[m,n,t];  

var PtR{t in T} = # Pt(R) Regenerators:
		sum{m in N, n in Nm[m], r in WR} (PGr[r] * Gmnr[m,n,r] * Wmnrt[m,n,r,t])	
;

var core_net_pc{t in T} = # Pt(IPoWDM) Power consumption of IP router ports
		PUEn * (PtIP[t] + PtT[t] + PtO[t] + PtE[t] + PtR[t]);

var metro_net_pc{t in T} = # Pt(Metro) Power consumption of Metro router and Ethernet switch ports:
	PUEn * (sum{i in N} PS * (MCQct[i,t] + CMQdt[i,t] + MAQdt[i,t]));

var access_net_pc{t in T} = # Pt(Access) Power consumption of OLTs in Access Network at time t:
	PUEn * sum{d in N} (Polt * OLTdt[d,t]);

param cdc_pc{t in T} = 0; # Pt(CDC) CDC power consumption at time t: (Green CDCs = 0)

var fdcb_pc{t in T} = # Pt(FDC - Brown): Brown FDC power consumption at time t:
	Pcs * PUEf * Zfdc * sum{s in S, d in N} VoDFBdst[d,s,t] * OLTdt[d,t];

var PCn = # Pt(N) Network Power consumption at time t:
	sum{t in T}(core_net_pc[t] + metro_net_pc[t] + access_net_pc[t]);

var BrownPower{t in T} = # PCbt Brown Power consumption at time t:
	core_net_pc[t] + metro_net_pc[t] + access_net_pc[t] + fdcb_pc[t];
	
####################################
## OBJECTIVE ##
minimize PCb: # Minimse the total brown energy consumption (PCb) over all times t in T
	sum{t in T} BrownPower[t]
;
####################################

## CONSTRAINTS ##
# 1) Flow Conservation in IP Layer
subject to Cons11 {c in CDC, d in N, i in N, t in T : c <> d}:
	sum{j in N : i <> j} Lcd_ijt[c,d,i,j,t] - 
	sum{j in N : i <> j} Lcd_ijt[c,d,j,i,t] =
	if i = c then VoDCcdt[c,d,t] else if i = d then -VoDCcdt[c,d,t] else 0;

# 2) Flow Conservation in Optical Layer
subject to Cons12 {i in N, j in N, m in N, r in WR, t in T : i <> j}:
	sum{n in Nm[m]} wmn_ijrt[m,n,i,j,r,t] -
	sum{n in Nm[m]} wmn_ijrt[n,m,i,j,r,t] =
	if m = i then Cijrt[i,j,r,t] else if m = j then -Cijrt[i,j,r,t] else 0;

# 3) Virtual IP link capacity constraint
subject to Cons13 {i in N, j in N, t in T : i <> j}:
	sum{c in CDC} sum{d in N : c <> d} Lcd_ijt[c,d,i,j,t] <= 
	sum{r in WR} Cijrt[i,j,r,t] * Br[r];

# 4) Capacity Constraints
# Ensure wavelengths in the physical link do not exceed the maximum capacity of the fibres
subject to Cons14 {m in N, n in Nm[m], t in T}:
	sum{i in N} sum{j in N : i <> j} sum{r in WR} wmn_ijrt[m,n,i,j,r,t] <=
	W * Fmnt[m,n,t];

# Calculate Wmnrt
subject to Cons15{m in N, n in Nm[m], r in WR, t in T : m <> n}:
	sum{i in N} sum{j in N : i <> j} wmn_ijrt[m,n,i,j,r,t] =
	Wmnrt[m,n,r,t];
	
# 5) Aggregation ports constraints
# Number of aggregation ports required to connect core node c with CDC
subject to Cons16 {c in CDC, t in T}:
	Bm * CCQct[c,t] = sum{d in N} VoDCcdt[c,d,t];

#Number of aggregation ports required to connect core node d with networking equipment of metro network at d	
subject to Cons17 {d in N, t in T}:
	Bm * CMQdt[d,t] = sum{c in CDC : c <> d} VoDCcdt[c,d,t];
	
# Number of aggregation ports required to connect the CDC c with metro node in c
subject to Cons18 {c in CDC, t in T}:
	Bm * MCQct[c,t] = sum{d in N : c = d} VoDCcdt[c,d,t];
	
# Number of aggregation ports required to connect metro networking equipment at node d with access network at d
subject to Cons19 {d in N, t in T}:
	Bm * MAQdt[d,t] = sum{c in CDC} VoDCcdt[c,d,t];
		
# 6) Number of OLTs in the access network
subject to Cons20 {d in N, t in T}:
	OLTdt[d,t] = sum{c in CDC} VoDcdt[c,d,t] / Colt;
	
# 7) Demands distribution
subject to Cons21 {c in CDC, d in N, t in T}:
	VoDCcdt[c,d,t] + (VoDFcdt[c,d,t] * OLTdt[d,t]) = VoDcdt[c,d,t];

# 8) OLT Capacity
subject to Cons22 {d in N, t in T}:
	sum{c in CDC} VoDFcdt[c,d,t] <= Cfdc;

# 9) Servers in FDCs
# Ensure demands per server do not exceed its capacity
subject to Cons23 {d in N, s in S, t in T}:
	VoDFSdst[d,s,t] + VoDFBdst[d,s,t] + VoDFEdst[d,s,t] <= Cs;
	
# Equates all servers to demands to the total FDC demands
subject to Cons24 {d in N, t in T}:
	sum{s in S} (VoDFSdst[d,s,t] + VoDFBdst[d,s,t] + VoDFEdst[d,s,t]) = sum{c in CDC} VoDFcdt[c,d,t];
	
# 10) Solar Power: Ensure that solar powered FDC servers do not exceed the available solar power
subject to Cons25 {d in N, t in T}:
	sum{s in S} (VoDFSdst[d,s,t] * Pcs * PUEf * Zfdc) <=
	SPdt[d,t] * SSC;

# 11) Discharge Limit
subject to Cons26 {d in N, t in T}:
	EDdt[d,t] <= Edt[d,t];

# 12) Charge Limit
subject to Cons27 {d in N, t in T}:
	RSdt[d,t] <= Emax - Edt[d,t];
	
# 13) Energy storage constraints
# Energy stored in ESDs at t compared to energy stored in ESDs at t-2 (previous time slot)
subject to Cons28 {d in N, t in T}:
	Edt[d,t] = if t <> 0 then 
		(Edt[d,t-SS] - EDdt[d,t-SS] + (Alpha * RSdt[d,t-SS]))
	else 0;
	
# Ensures energy stored in the ESD is within the maximum capacity
subject to Cons29 {d in N, t in T}:
	Edt[d,t] <= Emax;

# 14) Energy discharge
subject to Cons30{d in N, t in T}:
	SS * sum{s in S} VoDFEdst[d,s,t] * Pcs * PUEf * Zfdc <= Beta * EDdt[d,t];
	
# 15) Surplus renewable energy
subject to Cons31{d in N, t in T: t <> 0}:
	SS * SSC * SPdt[d,t-SS] = RSdt[d,t] + SS * (sum{s in S} VoDFSdst[d,s,t]) * Pcs * PUEf * Zfdc; 

# 16) Prevent energy storage at t = 0
subject to Cons32{d in N}:
	RSdt[d,0] <=0;	