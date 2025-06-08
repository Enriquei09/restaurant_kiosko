
import 'package:flutter/material.dart';

class BuildHeader extends StatelessWidget {

  const BuildHeader({
    super.key
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset('assets/img_comida/img_log.png',height: 60),
          const Spacer(),
          Image.asset('assets/img_comida/Img_logo2.png',height: 80),
          const Spacer(),
          ElevatedButton(
            onPressed: (){},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white
            ),
            child: const Text('Orden')
          
          ),
          const SizedBox(width: 12,),
          const Icon(Icons.person_3_outlined)
          
        ],
      ),
    );
  }

 
  

  
}